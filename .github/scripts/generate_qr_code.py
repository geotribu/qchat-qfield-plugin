import os
import qrcode

url = os.environ["FILE_URL"]
img = qrcode.make(url)
img.save("qrcode.png")
print(f"QR code generated for: {url}")
