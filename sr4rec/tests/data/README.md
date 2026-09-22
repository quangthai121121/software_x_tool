# Test data

`resize_golden.npz`: reference outputs of MATLAB-style bicubic `imresize` for two small random
images (downsampling x2, x3, x4 and upsampling x4). They were produced once with the BasicSR 1.4.2
port of MATLAB `imresize` (`basicsr/utils/matlab_functions.py`, Apache-2.0). Replace them with
values produced by MATLAB itself (`imresize(img, s, 'bicubic')`) when MATLAB is available (B2.3).
