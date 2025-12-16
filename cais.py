# Caesar Cipher (Shift = +4 based on the example APPLE -> ETTPI)

alphabet = [chr(i) for i in range(ord('A'), ord('Z') + 1)]

text = input("Enter UPPERCASE text to encrypt: ")

encrypted = ""

for char in text:
    if char in alphabet:
        pos = alphabet.index(char)
        new_pos = (pos + 4) % 26     # Shift = 4 to match example
        encrypted += alphabet[new_pos]
    else:
        encrypted += char  # Preserve non-alphabet characters

print("Encrypted text:", encrypted)