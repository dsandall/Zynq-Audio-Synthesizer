import random

# Function to generate 16-bit signed random noise values


def generate_16bit_signed_noise(num_samples):
    noise_values = [random.randint(-32768, 32767) for _ in range(num_samples)]
    return noise_values


# Example usage: Generate 10 random 16-bit signed noise values
num_samples = 256
noise_list = generate_16bit_signed_noise(num_samples)

# Print the generated noise values
print(noise_list)
