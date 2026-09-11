from PIL import Image

def print_ascii(path, width=80):
    try:
        img = Image.open(path)
        img = img.convert('L')
        aspect_ratio = img.height / img.width
        new_height = int(width * aspect_ratio * 0.5)
        img = img.resize((width, new_height))
        pixels = img.getdata()
        chars = ["@", "%", "#", "*", "+", "=", "-", ":", ".", " "]
        new_pixels = [chars[pixel//26] for pixel in pixels]
        new_pixels = ''.join(new_pixels)
        pixel_count = len(new_pixels)
        ascii_image = [new_pixels[index:index+width] for index in range(0, pixel_count, width)]
        print(f"\n--- {path} ---")
        print("\n".join(ascii_image))
    except Exception as e:
        print(f"Failed {path}: {e}")

print_ascii("DeskPetPomodoro/Resources/dog_walking.png", 60)
print_ascii("DeskPetPomodoro/Resources/cat_walking.png", 60)
