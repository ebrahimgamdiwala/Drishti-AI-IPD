"""
Drishti AI - Gemini Vision Service

Backend-owned Gemini integration for mobile vision requests.
"""

from __future__ import annotations

import json
import time
from typing import Any

import httpx

from app.config import get_settings


def _candidate_models() -> list[str]:
    settings = get_settings()
    models = [
        settings.gemini_model,
        settings.gemini_fallback_model,
        "gemini-2.5-flash",
        "gemini-flash-latest",
    ]

    deduped: list[str] = []
    seen: set[str] = set()
    for model in models:
        cleaned = model.strip()
        if cleaned and cleaned not in seen:
            deduped.append(cleaned)
            seen.add(cleaned)
    return deduped


def _build_payload(image_base64: str, prompt: str, image_mime: str) -> dict[str, Any]:
    return {
        "systemInstruction": {
            "parts": [
                {
                    "text": (
                        "You are Drishti, a mobile accessibility vision assistant. "
                        "Return strict JSON only. Prioritize hazards, people, text, "
                        "and spatial awareness. Keep descriptions concise but a bit fuller, "
                        "usually 2 to 4 short sentences with practical detail for a visually impaired user."
                    )
                }
            ]
        },
        "contents": [
            {
                "role": "user",
                "parts": [
                    {
                        "inlineData": {
                            "mimeType": image_mime,
                            "data": image_base64,
                        }
                    },
                    {
                        "text": (
                            f"{prompt}\n\n"
                            "Respond with slightly more detail than a one-line answer. "
                            "Keep it practical, direct, and easy to listen to."
                        )
                    },
                ],
            }
        ],
        "generationConfig": {
            "responseMimeType": "application/json",
            "responseSchema": {
                "type": "object",
                "properties": {
                    "description": {"type": "string"},
                    "objects": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "label": {"type": "string"},
                                "confidence": {"type": "number"},
                                "box_2d": {
                                    "type": "array",
                                    "items": {"type": "number"},
                                    "minItems": 4,
                                    "maxItems": 4,
                                },
                            },
                            "required": ["label"],
                        },
                    },
                },
                "required": ["description"],
            },
            "maxOutputTokens": 900,
            "temperature": 0.2,
            "mediaResolution": "MEDIA_RESOLUTION_MEDIUM",
        },
    }


def _extract_candidate_text(data: dict[str, Any]) -> str:
    candidates = data.get("candidates") or []
    if not candidates:
        raise ValueError("Gemini returned no candidates.")

    first_candidate = candidates[0]
    finish_reason = first_candidate.get("finishReason")
    if finish_reason and finish_reason not in {"STOP", "FINISH_REASON_UNSPECIFIED"}:
        raise ValueError(f"Gemini finished with {finish_reason}")

    parts = ((first_candidate.get("content") or {}).get("parts") or [])
    for part in parts:
        text = (part or {}).get("text")
        if isinstance(text, str) and text.strip():
            return text

    raise ValueError("Gemini response did not contain text output.")


def _parse_objects(objects_data: Any) -> list[dict[str, Any]]:
    if not isinstance(objects_data, list):
        return []

    parsed_objects: list[dict[str, Any]] = []
    for item in objects_data:
        if not isinstance(item, dict):
            continue

        label = str(item.get("label", "")).strip()
        if not label:
            continue

        confidence = item.get("confidence", 0.7)
        try:
            confidence = max(0.0, min(float(confidence), 1.0))
        except (TypeError, ValueError):
            confidence = 0.7

        box_2d = item.get("box_2d")
        if not isinstance(box_2d, list) or len(box_2d) != 4:
            box_2d = [400, 400, 600, 600]

        parsed_objects.append(
            {
                "label": label,
                "confidence": confidence,
                "box_2d": box_2d,
            }
        )

    return parsed_objects


async def analyze_image_with_gemini(
    image_base64: str,
    prompt: str,
    image_mime: str = "image/jpeg",
) -> dict[str, Any]:
    settings = get_settings()

    if not settings.gemini_api_key:
        return {"success": False, "error": "Gemini API key is not configured on the backend."}

    last_error = "Gemini request failed."
    async with httpx.AsyncClient(timeout=httpx.Timeout(45.0, connect=15.0)) as client:
        for model in _candidate_models():
            started = time.perf_counter()
            try:
                response = await client.post(
                    f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent",
                    params={"key": settings.gemini_api_key},
                    json=_build_payload(image_base64, prompt, image_mime),
                    headers={
                        "Content-Type": "application/json",
                        "Accept": "application/json",
                    },
                )
            except httpx.ConnectError:
                return {
                    "success": False,
                    "error": "Could not reach Gemini from the backend.",
                }
            except httpx.TimeoutException:
                return {
                    "success": False,
                    "error": "Gemini request timed out on the backend.",
                }
            except Exception as exc:
                last_error = str(exc)
                break

            if response.status_code == 404:
                last_error = f"Gemini model not found: {model}"
                continue

            if response.status_code >= 400:
                body = response.text[:500]
                return {
                    "success": False,
                    "error": f"Gemini returned HTTP {response.status_code}: {body}",
                }

            try:
                data = response.json()
                prompt_feedback = data.get("promptFeedback") or {}
                if prompt_feedback.get("blockReason"):
                    return {
                        "success": False,
                        "error": f"Gemini blocked the request: {prompt_feedback['blockReason']}",
                    }

                response_text = _extract_candidate_text(data)
                decoded = json.loads(response_text)
                description = str(decoded.get("description", "")).strip() or "No scene description returned."
                usage = data.get("usageMetadata") or {}

                return {
                    "success": True,
                    "engine": "gemini",
                    "response": description,
                    "description": description,
                    "objects": _parse_objects(decoded.get("objects")),
                    "model": model,
                    "prompt_tokens": int(usage.get("promptTokenCount", 0) or 0),
                    "completion_tokens": int(usage.get("candidatesTokenCount", 0) or 0),
                    "inference_ms": int((time.perf_counter() - started) * 1000),
                }
            except Exception as exc:
                last_error = str(exc)
                break

    return {"success": False, "error": last_error}


async def check_gemini_health() -> dict[str, Any]:
    settings = get_settings()
    return {
        "configured": bool(settings.gemini_api_key),
        "primaryModel": settings.gemini_model,
        "fallbackModel": settings.gemini_fallback_model,
    }