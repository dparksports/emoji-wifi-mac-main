import wifi_qrcode_generator.generator

# 1. prompt the user for input
wifi_name = input("Enter the Wi-Fi Name (SSID): ")
wifi_password = input("Enter the Wi-Fi Password: ")

# 2. Generate the QR code using the provided variables
qr_code = wifi_qrcode_generator.generator.wifi_qrcode(
    ssid=wifi_name,
    hidden=False,
    authentication_type='WPA',
    password=wifi_password
)

# 3. Output the result
qr_code.print_ascii()
qr_code.make_image().save('qr.png')

print(f"\nSuccess! QR code for '{wifi_name}' has been saved as 'qr.png'.")