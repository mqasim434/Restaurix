from PIL import Image
from pathlib import Path

src = Path(r"D:\Restaurix\restaurix\assets\images\restauix icon.png")
dst = Path(r"D:\Restaurix\restaurix\windows\runner\resources\app_icon.ico")

img = Image.open(src).convert("RGBA")
sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]

# Pillow ICO writer accepts sizes= and encodes each resolution from the source.
img.save(dst, format="ICO", sizes=sizes)
print(f"Wrote {dst} ({dst.stat().st_size} bytes)")

# Verify entries roughly
with open(dst, "rb") as f:
    data = f.read(6)
    count = int.from_bytes(data[4:6], "little")
    print(f"ICO image count: {count}")
