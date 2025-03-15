
import numpy as np
import scipy.signal as signal
import matplotlib.pyplot as plt


# Filter Orders
order_101 = 101  # 101-order filter
order_31 = 23    # 31-order filter
# Parameters
fs = 48000  # Sampling rate (Hz)
nyquist = fs / 2
cutoff = 5000  # Cutoff frequency
highpass = True

##
##
##

# Normalize the cutoff frequency
normalized_cutoff = cutoff / nyquist

# Design the low-pass filters (FIR) using the window method for both orders
if highpass:
    pz = False
    print("generating highpass")
else:
    pz = True
    print("generating low-pass")

b_101 = signal.firwin(order_101, normalized_cutoff, pass_zero=pz)
b_31 = signal.firwin(order_31, normalized_cutoff, pass_zero=pz)

# Scale the coefficients to 16-bit signed integers
# Scale and convert to 16-bit signed integer
scaled_b_101 = np.round(b_101 * (2**15)).astype(np.int16)
# Scale and convert to 16-bit signed integer
scaled_b_31 = np.round(b_31 * (2**15)).astype(np.int16)

# Plot the frequency response of both filters
w_101, h_101 = signal.freqz(b_101, worN=2000)
w_31, h_31 = signal.freqz(b_31, worN=2000)

# Convert magnitude response to dB
# Adding small epsilon to avoid log(0)
h_101_db = 20 * np.log10(abs(h_101) + 1e-12)
h_31_db = 20 * np.log10(abs(h_31) + 1e-12)

# Plot
plt.figure(figsize=(10, 6))

# Plot the 101-order filter (in dB)
plt.subplot(2, 1, 1)
plt.plot((w_101 / np.pi) * nyquist, h_101_db, 'b')
plt.title('Frequency Response of 101-Order Low-Pass Filter (dB)')
plt.xlabel('Frequency (Hz)')
plt.ylabel('Magnitude (dB)')
plt.grid(True)
plt.xlim(0, nyquist)

# Plot the 31-order filter (in dB)
plt.subplot(2, 1, 2)
plt.plot((w_31 / np.pi) * nyquist, h_31_db, 'r')
plt.title('Frequency Response of 31-Order Low-Pass Filter (dB)')
plt.xlabel('Frequency (Hz)')
plt.ylabel('Magnitude (dB)')
plt.grid(True)
plt.xlim(0, nyquist)

plt.tight_layout()
plt.show()

# Export the 16-bit scaled filter coefficients to a file
# Save the 31-order filter coefficients to CSV without scientific notation
np.savetxt("low_pass_31_order_coefficients_16bit.csv", scaled_b_31, fmt='%d',
           delimiter=',', header="31-Order Filter Coefficients (16-bit Signed)", comments='')

# Optionally, also export 101-order filter coefficients
np.savetxt("low_pass_101_order_coefficients_16bit.csv", scaled_b_101, fmt='%d',
           delimiter=',', header="101-Order Filter Coefficients (16-bit Signed)", comments='')
