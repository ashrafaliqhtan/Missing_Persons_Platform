def caesar_cipher_encrypt(text):
    """
    Encrypts text using Caesar Cipher with shift of 3 positions
    """
    # Create alphabet list A-Z
    alphabet = [chr(i) for i in range(65, 91)]  # A to Z
    
    encrypted_text = ""
    
    for char in text:
        if char.isalpha() and char.isupper():
            # Get current position in alphabet (0-25)
            current_pos = ord(char) - 65
            # Calculate new position with shift of 3
            new_pos = (current_pos + 3) % 26
            # Add encrypted character
            encrypted_text += alphabet[new_pos]
        else:
            # Keep non-alphabetic characters as they are
            encrypted_text += char
    
    return encrypted_text

def main():
    print("=== Caesar Cipher Encryption ===")
    print("Shift: 3 positions forward")
    print("Alphabet: A-Z (Capital Letters only)")
    print("-" * 40)
    
    # Ask user for input
    user_input = input("Enter text in UPPERCASE for encryption: ")
    
    # Encrypt the text
    encrypted = caesar_cipher_encrypt(user_input)
    
    # Display results
    print(f"\nOriginal text: {user_input}")
    print(f"Encrypted text: {encrypted}")

# Run the program
if __name__ == "__main__":
    main()
    
    
    
 """ part 2 """
 
 def create_employee_file():
    """Create a text file with employee records"""
    
    # Get user's name for the filename
    user_name = input("Enter your name for the filename: ").strip()
    filename = f"{user_name}.txt"
    
    print(f"\nCreating file: {filename}")
    print("Enter employee records in the format: Full Name, Job Title, Salary")
    print("Enter 'done' when finished\n")
    
    # Open file for writing
    with open(filename, 'w') as file:
        record_count = 0
        
        while record_count < 7:  # We need at least 7 records
            record = input(f"Enter record {record_count + 1}: ")
            
            if record.lower() == 'done' and record_count >= 7:
                break
            elif record.lower() == 'done':
                print("Please enter at least 7 records!")
                continue
                
            # Write record to file
            file.write(record + '\n')
            record_count += 1
    
    # Read and display file contents
    print(f"\nContent of {filename}:")
    print("-" * 40)
    with open(filename, 'r') as file:
        content = file.read()
        print(content)
    
    return filename

# Execute the program
if __name__ == "__main__":
    create_employee_file()
    
    
    
 
 
 
 """ part 3"""
 
 
 def process_employee_file():
    """Process the employee file and display lecturer information"""
    
    filename = "Hadi Awad.txt"  # Using the specified name
    
    print(f"Reading from file {filename}")
    print("-" * 40)
    
    # Initialize variables
    lecturer_count = 0
    total_lecturer_salary = 0
    
    # Read and process the file
    with open(filename, 'r') as file:
        for line in file:
            # Remove whitespace and skip empty lines
            line = line.strip()
            if not line:
                continue
                
            # Split the record into name, job, and salary
            parts = line.split(', ')
            if len(parts) >= 3:
                full_name = parts[0]
                job = parts[1]
                salary = float(parts[2])
                
                # Split name into first and last
                name_parts = full_name.split(' ')
                if len(name_parts) >= 2:
                    last_name = name_parts[0]
                    first_name = name_parts[1] if len(name_parts) > 1 else ""
                    
                    # Calculate final income with 10% bonus
                    final_income = salary * 1.10
                    
                    # Check if the employee is a Lecturer
                    if "Lecturer" in job:
                        lecturer_count += 1
                        total_lecturer_salary += final_income
                        
                        print(f"Name: {last_name}, {first_name}")
                        print(f"Job: {job}")
                        print(f"Income: ${final_income}")
                        print()
    
    # Calculate and display average salary for lecturers
    if lecturer_count > 0:
        average_salary = total_lecturer_salary / lecturer_count
        print(f"The average of the Lecturers' salaries is: {average_salary}")
    else:
        print("No lecturers found in the records.")

# Execute the program
if __name__ == "__main__":
    process_employee_file()
    
    
    
    
 """
 
 
 text 
 
 
Reading from file Hadi Awad.txt
Name: Mikati, Ahmad  Job: Lecturer   Income: $2200.0
Name: Hachem, Nizar    Job: Lecturer    Income: $1980.0
Name: Saeed, Fadwa     Job: Lecturer    Income: $2090.0
Name: Khattar, Nadine    Job: Lecturer    Income: $1628.0
The average of the Lecturers' salaries is: 1974.5 
 
    """
    
    
    