"""
YOLOv8 Live Object Detection using Laptop Camera
Supports COCO, Mapillary, and WOTR datasets.
Author: Your Name
"""

import cv2
import torch
from ultralytics import YOLO
import argparse
import os
import pyttsx3
import threading
import queue
import time
from collections import defaultdict, deque, Counter
import numpy as np

# Threaded Text-to-Speech (TTS) Worker (Corrected Version 2 - More Stable)
class TTSWorker:
    """Background worker that handles TTS requests using pyttsx3.

    Benefits:
    - Non-blocking: main loop can enqueue alerts without waiting for speech to finish.
    - Coalescing: multiple alerts can be combined into one utterance to reduce verbosity.
    - Cooldowns: respects a global minimum gap between speeches.
    """
    def __init__(self, min_gap=0.8, engine_rate_delta=25, max_queue_size=50):
        self.queue = queue.Queue(maxsize=max_queue_size)
        self.min_gap = float(min_gap)
        self.engine_rate_delta = engine_rate_delta
        self.last_spoken_time = 0.0
        self._stop_event = threading.Event()
        self.thread = threading.Thread(target=self._run, daemon=True)

    def start(self):
        self.thread.start()

    def stop(self, wait=True):
        self._stop_event.set()
        try:
            self.queue.put_nowait(None)
        except Exception:
            pass
        if wait and self.thread.is_alive():
            self.thread.join(timeout=2.0)

    def enqueue(self, text, force=False):
        if not text:
            return False
        try:
            if self.queue.full() and not force:
                try:
                    self.queue.get_nowait()
                except Exception:
                    pass
            self.queue.put_nowait(text)
            return True
        except Exception:
            return False

    def _run(self):
        while not self._stop_event.is_set():
            try:
                item = self.queue.get()
                if item is None:
                    break

                texts = [item]
                while True:
                    try:
                        more = self.queue.get_nowait()
                        if more is None:
                            self.queue.put_nowait(None)
                            break
                        texts.append(more)
                    except queue.Empty:
                        break

                if len(texts) > 3:
                    texts = texts[:3] + ["and more alerts."]

                utterance = ". ".join(texts)

                now = time.time()
                if now - self.last_spoken_time < self.min_gap:
                    remaining = self.min_gap - (now - self.last_spoken_time)
                    if remaining > 0:
                        self._wait_or_stop(remaining)
                
                if self._stop_event.is_set(): break

                # ✨ KEY CHANGE: Manual event loop for stability ✨
                try:
                    engine = pyttsx3.init()
                    rate = engine.getProperty('rate')
                    engine.setProperty('rate', max(80, rate - self.engine_rate_delta))
                    
                    print(f"📢 SPEAKING (queued): {utterance}")
                    engine.say(utterance)
                    
                    # Manually drive the event loop instead of runAndWait()
                    engine.startLoop(False)
                    while engine.isBusy() and not self._stop_event.is_set():
                        engine.iterate()
                        time.sleep(0.05) # Prevent CPU hogging
                    engine.endLoop()
                    engine.stop()
                    
                    self.last_spoken_time = time.time()

                except Exception as e:
                    # This can happen if the TTS driver is not available or fails
                    print(f"⚠️ TTS driver error: {e}")

            except Exception as e:
                print(f"⚠️ Unexpected error in TTS worker: {e}")

    def _wait_or_stop(self, seconds):
        end = time.time() + seconds
        while time.time() < end and not self._stop_event.is_set():
            time.sleep(0.05)


# Create a global TTS worker instance (started in main)
tts_worker = None

def speak(text):
    """Enqueue text for speech via the TTS worker if available."""
    global tts_worker
    if not text:
        return
    if tts_worker:
        tts_worker.enqueue(text)
    else:
        # Last-resort synchronous fallback (should ideally not be used if worker starts)
        try:
            engine = pyttsx3.init()
            print(f"📢 SPEAKING (fallback): {text}")
            engine.say(text)
            engine.runAndWait()
        except Exception as e:
            print(f"⚠️ TTS fallback failed: {e}")

# This function will contain all your main logic
def main():
    # ------------------------------
    # ⚙️ Argument Parser
    # ------------------------------
    parser = argparse.ArgumentParser(description="YOLOv8 Live Object Detection")
    parser.add_argument("--dataset", type=str, default="wotr",
                        choices=["coco", "mapillary", "wotr"],
                        help="Choose between 'coco', 'mapillary', or 'wotr'")
    parser.add_argument("--train", action="store_true",
                        help="Enable training mode for the WOTR dataset.")
    parser.add_argument("--ensemble", action="store_true",
                        help="Run inference with both COCO and WOTR models and display combined detections.")
    args = parser.parse_args()

    # ------------------------------
    # 🔧 Model Configuration
    # ------------------------------
    if torch.cuda.is_available():
        print("✅ GPU detected — high-performance mode.")
    else:
        print("⚙️ CPU detected — running in low-power mode.")

    # Model paths
    COCO_MODEL_PATH = "yolov8n.pt"
    MAPILLARY_MODEL_PATH = "runs/detect/mapillary/weights/best.pt"
    WOTR_MODEL_PATH = "runs/detect/train/weights/best.pt"
    
    WOTR_YAML_PATH = "wotr.yaml"

    model = None
    ensemble_models = {}

    # ------------------------------
    # 🚀 Training Logic (Optional)
    # ------------------------------
    if args.train:
        if args.dataset != "wotr":
            print("⚠️ Training is only supported for the 'wotr' dataset. Please specify --dataset wotr.")
            exit(1)
        
        print("✅ Training mode enabled for WOTR dataset.")
        print("📦 Loading base model for training...")
        model = YOLO(COCO_MODEL_PATH)
        print("🚀 Starting training... This may take a while.")
        
        try:
            # Ensure the weights directory exists
            weights_dir = os.path.join("runs", "detect", "train", "weights")
            os.makedirs(weights_dir, exist_ok=True)
            
            model.train(
                data=WOTR_YAML_PATH,
                epochs=25,
                imgsz=640,
                patience=5,
                workers=4,
                batch=8,
                save=True,
                save_period=1,
                exist_ok=True,
                device=0,
                project="runs/detect",
                name="train"
            )

            save_dir = os.path.join("runs", "detect", "train")
            weights_dir = os.path.join(save_dir, "weights")
            print(f"🎉 Training complete. Checking for weights in {weights_dir}...")
            best_path = os.path.join(weights_dir, "best.pt")
            last_path = os.path.join(weights_dir, "last.pt")
            if os.path.exists(best_path):
                print(f"📦 Loading best checkpoint: {best_path}")
                model = YOLO(best_path)
            elif os.path.exists(last_path):
                print(f"📦 Loading last checkpoint: {last_path}")
                model = YOLO(last_path)
            else:
                print("⚠️ No checkpoints found after training. Falling back to COCO pretrained model.")
                model = YOLO(COCO_MODEL_PATH)
        except Exception as e:
            import traceback
            print(f"❌ An error occurred during training: {e}")
            traceback.print_exc()
            exit(1)

    else:
        # Load appropriate model for inference
        if args.ensemble:
            print("🔀 Ensemble mode enabled: attempting to load both COCO and WOTR models.")
            try:
                ensemble_models['coco'] = YOLO(COCO_MODEL_PATH)
                print("✅ COCO model loaded for ensemble.")
            except Exception:
                print("⚠️ Failed to load COCO model for ensemble.")
            
            if os.path.exists(WOTR_MODEL_PATH):
                try:
                    ensemble_models['wotr'] = YOLO(WOTR_MODEL_PATH)
                    print("✅ WOTR model loaded for ensemble.")
                except Exception:
                    print("⚠️ Failed to load WOTR model for ensemble.")
            else:
                print("⚠️ WOTR weights not found for ensemble; only COCO will be used if available.")

            if not ensemble_models:
                print("⚠️ No models loaded for ensemble; falling back to single-model mode.")

        if args.dataset == "mapillary":
            if os.path.exists(MAPILLARY_MODEL_PATH):
                print("📦 Loading Mapillary-trained model...")
                model = YOLO(MAPILLARY_MODEL_PATH)
            else:
                print("⚠️ Mapillary weights not found! Falling back to COCO model.")
                model = YOLO(COCO_MODEL_PATH)
        elif args.dataset == "wotr":
            if os.path.exists(WOTR_MODEL_PATH):
                print("📦 Loading custom WOTR-trained model...")
                model = YOLO(WOTR_MODEL_PATH)
            else:
                print("⚠️ WOTR weights not found! Please train the model first using the --train flag.")
                exit(1)
        else:
            print("📦 Loading COCO pretrained model...")
            model = YOLO(COCO_MODEL_PATH)
        
        print("✅ Model loaded successfully.")

    # ------------------------------
    # 🎥 Open Laptop Camera
    # ------------------------------
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("❌ ERROR: Could not access laptop camera.")
        exit(1)

    font = cv2.FONT_HERSHEY_SIMPLEX
    print(f"🚀 Starting live detection with audio alerts... Press 'q' to quit.")

    # Variables for tracking and alerts
    object_history = defaultdict(lambda: None)
    object_labels = defaultdict(lambda: deque(maxlen=7))
    PROXIMITY_THRESHOLD = 0.5
    SPEED_THRESHOLD = 40

    # TTS cooldowns (seconds)
    PER_ALERT_COOLDOWN = 5.0
    GLOBAL_TTS_COOLDOWN = 0.8
    last_spoken = defaultdict(lambda: 0.0)

    # Start the TTS worker
    global tts_worker
    try:
        tts_worker = TTSWorker(min_gap=GLOBAL_TTS_COOLDOWN)
        tts_worker.start()
    except Exception as e:
        print(f"⚠️ Could not start TTS worker: {e}")

    # ------------------------------
    # 🔍 Real-time Detection Loop
    # ------------------------------
    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                print("⚠️ Empty frame. Retrying...")
                continue
            
            frame_height, frame_width, _ = frame.shape
            screen_area = frame_height * frame_width

            if args.ensemble and ensemble_models:
                results_coco = ensemble_models.get('coco').predict(source=frame, conf=0.4, imgsz=640, verbose=False) if 'coco' in ensemble_models else []
                results_wotr = ensemble_models.get('wotr').predict(source=frame, conf=0.4, imgsz=640, verbose=False) if 'wotr' in ensemble_models else []
            else:
                results = model.track(source=frame, persist=True, tracker="botsort.yaml", verbose=False)

            alerts_to_speak = []

            if args.ensemble and ensemble_models:
                all_dets = []

                def collect_dets(res_list, source_name):
                    for r in res_list:
                        names = getattr(r, 'names', None) or {}
                        for box in r.boxes:
                            x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())
                            conf = float(box.conf[0])
                            cls = int(box.cls[0])
                            label = names.get(cls, f"class_{cls}")
                            all_dets.append({
                                'box': [x1, y1, x2, y2],
                                'conf': conf,
                                'label': label,
                                'source': source_name
                            })

                if 'coco' in ensemble_models:
                    collect_dets(results_coco, 'coco')
                if 'wotr' in ensemble_models:
                    collect_dets(results_wotr, 'wotr')

                def iou(a, b):
                    x1 = max(a[0], b[0])
                    y1 = max(a[1], b[1])
                    x2 = min(a[2], b[2])
                    y2 = min(a[3], b[3])
                    inter_w = max(0, x2 - x1)
                    inter_h = max(0, y2 - y1)
                    inter = inter_w * inter_h
                    area_a = (a[2] - a[0]) * (a[3] - a[1])
                    area_b = (b[2] - b[0]) * (b[3] - b[1])
                    union = area_a + area_b - inter
                    return inter / union if union > 0 else 0.0

                iou_thresh = 0.5
                kept = []
                dets_sorted = sorted(all_dets, key=lambda d: d['conf'], reverse=True)
                for det in dets_sorted:
                    keep = True
                    for k in kept:
                        if iou(det['box'], k['box']) > iou_thresh:
                            keep = False
                            break
                    if keep:
                        kept.append(det)

                for det in kept:
                    x1, y1, x2, y2 = det['box']
                    conf = det['conf']
                    label_for_alert = det['label']
                    
                    box_area = (x2 - x1) * (y2 - y1)
                    if box_area / screen_area > PROXIMITY_THRESHOLD:
                        alert_msg = f"Warning, {label_for_alert} very close."
                        if alert_msg not in alerts_to_speak:
                            alerts_to_speak.append(alert_msg)
                        cv2.putText(frame, "PROXIMITY ALERT!", (x1, y1 - 30), font, 0.7, (0, 0, 255), 2)
                    
                    color = (255, 0, 0) if det['source'] == 'coco' else (0, 255, 0)
                    cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
                    cv2.putText(frame, f"{label_for_alert} {conf:.2f}", (x1, y1 - 8), font, 0.6, (255, 255, 255), 2)
            else:
                if results[0].boxes.id is None:
                    cv2.imshow("YOLOv8 Live Object Detection", frame)
                    if cv2.waitKey(1) & 0xFF == ord('q'):
                        break
                    continue

                boxes = results[0].boxes.xyxy.cpu().numpy().astype(int)
                ids = results[0].boxes.id.cpu().numpy().astype(int)
                clss = results[0].boxes.cls.cpu().numpy().astype(int)

                for box, obj_id, cls_id in zip(boxes, ids, clss):
                    x1, y1, x2, y2 = box
                    raw_name = model.names.get(cls_id, f"class_{cls_id}")
                    object_labels[obj_id].append(raw_name)
                    most_common = Counter(object_labels[obj_id]).most_common(1)
                    name = most_common[0][0] if most_common else raw_name
                    
                    if name == 'dog':
                        box_h = y2 - y1
                        box_w = x2 - x1
                        if box_h > frame_height * 0.35 and box_h > box_w * 1.1:
                            name = 'person'
                    
                    box_area = (x2 - x1) * (y2 - y1)
                    if box_area / screen_area > PROXIMITY_THRESHOLD:
                        alert_msg = f"Warning, {name} very close."
                        if alert_msg not in alerts_to_speak:
                            alerts_to_speak.append(alert_msg)
                        cv2.putText(frame, "PROXIMITY ALERT!", (x1, y1 - 30), font, 0.7, (0, 0, 255), 2)

                    center_x, center_y = int((x1 + x2) / 2), int((y1 + y2) / 2)
                    
                    prev_position = object_history[obj_id]
                    if prev_position is not None:
                        distance_moved = np.sqrt((center_x - prev_position[0])**2 + (center_y - prev_position[1])**2)
                        
                        if distance_moved > SPEED_THRESHOLD:
                            alert_msg = f"Caution, fast moving {name}."
                            if alert_msg not in alerts_to_speak:
                                alerts_to_speak.append(alert_msg)
                            cv2.putText(frame, "MOTION ALERT!", (x1, y1 - 50), font, 0.7, (0, 165, 255), 2)
                    
                    object_history[obj_id] = (center_x, center_y)

                    cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                    label = f"ID:{obj_id} {name}"
                    cv2.putText(frame, label, (x1, y1 - 8), font, 0.6, (255, 255, 255), 2)

            if alerts_to_speak:
                now = time.time()
                to_speak = []
                for alert in alerts_to_speak:
                    if now - last_spoken[alert] >= PER_ALERT_COOLDOWN:
                        to_speak.append(alert)
                        last_spoken[alert] = now

                if to_speak:
                    if len(to_speak) > 3:
                        to_speak = to_speak[:3] + [f"and {len(to_speak) - 3} more alerts"]
                    full_alert_string = ". ".join(to_speak)
                    speak(full_alert_string)

            cv2.imshow("YOLOv8 Live Object Detection", frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
    except KeyboardInterrupt:
        print("\n🛑 Interrupted by user.")
    except Exception as e:
        print(f"❌ Runtime error: {e}")
    finally:
        # ------------------------------
        # 🔚 Cleanup
        # ------------------------------
        try:
            cap.release()
        except Exception:
            pass
        try:
            cv2.destroyAllWindows()
        except Exception:
            pass
        try:
            if tts_worker:
                tts_worker.stop(wait=True)
        except Exception:
            pass

if __name__ == '__main__':
    main()