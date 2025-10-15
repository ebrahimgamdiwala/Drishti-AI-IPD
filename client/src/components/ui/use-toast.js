import { toast as hotToast } from 'react-hot-toast'

export function toast({ title = '', description = '', variant = 'default' } = {}) {
  const message = title ? `${title}${description ? ' — ' + description : ''}` : description
  if (variant === 'destructive') {
    hotToast.error(message)
  } else {
    hotToast(message)
  }
}

export default hotToast
