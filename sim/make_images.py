from PIL import Image, ImageDraw

# # make 320*180 image with black square in the middle
# img = Image.new('RGB', (320, 180), color = 'white')
# d = ImageDraw.Draw(img)
# d.rectangle([(120, 60), (180, 120)], fill='black')
# img.save('sim/images/square.png')


# # make 320*180 image with black circle in the middle
# img = Image.new('RGB', (320, 180), color = 'white')
# d = ImageDraw.Draw(img)
# d.ellipse([(120, 60), (180, 120)], fill='black')
# img.save('sim/images/circle.png')

# # make a 320*180 image with black triangle in the middle
# img = Image.new('RGB', (320, 180), color = 'white')
# d = ImageDraw.Draw(img)
# d.polygon([(120, 120), (180, 120), (150, 60)], fill='black')
# img.save('sim/images/triangle.png')

# # Create an image with a white background
# image_size = (320, 180)  # Width x Height
# image = Image.new("RGB", image_size, "white")
# draw = ImageDraw.Draw(image)

# # Draw a plus sign in the center of the image
# line_width = 30
# center_x, center_y = image_size[0] // 2, image_size[1] // 2
# line_length = 50

# # Horizontal line
# draw.rectangle(
#     [center_x - line_length, center_y - line_width // 2,
#      center_x + line_length, center_y + line_width // 2],
#     fill="black"
# )

# # Vertical line
# draw.rectangle(
#     [center_x - line_width // 2, center_y - line_length,
#      center_x + line_width // 2, center_y + line_length],
#     fill="black"
# )

# # Display the image
# image.save('sim/images/plus.png')


# iterate through image and return list of 0 and 1 
def get_image_data(image_path):
    image = Image.open(image_path)
    image_data = []
    for y in range(image.height):
        for x in range(image.width):
            pixel = image.getpixel((x, y))
            if pixel == (0, 0, 0):
                image_data.append(1)
            else:
                image_data.append(0)
    return image_data

#print(get_image_data('sim/images/square.png'))