import time
import random
from pynput.mouse import Controller

mouse = Controller()

while True:
    a = random.randint(1,5)
    b = 6-a
    c = random.randint(1,3)
    d = random.randint(1,3)
    print(f"Scroll Down: {c} units")
    mouse.scroll(0, -c)
    print(f"Sleeping for {a} seconds.")
    time.sleep(a)
    
    print(f"Scroll Up: {d} units")
    mouse.scroll(0, d)
    print(f"Sleeping for {b} seconds.")
    time.sleep(b)