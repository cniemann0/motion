#
# random_sequence.py
#
# Display a new movement and sleep for a random time.
#
# The user always performs the currently displayed movement and records the whole session (for example 2 minutes).
# The recording on the smartphone has to be aligned with the program, to allow for a manual annotation of the recorded
# motion data from the smartphone. This can be achieved by starting both at the same time.
# This represents the real-world scenario of controlling a game, where the movement should spontaneously change.
# The user doesnt know when and which movement is displayed next.
#


from random import randint
import time

duration = 185
min_seq = 8
max_seq = 10

movements = ["rechts", "links", "oben"]
rm = randint(0, len(movements) - 1)


for i in range(3):
    print(3-i)
    time.sleep(1)


start = time.time()
while (time.time() - start) < duration:
    while 1:
        rm_new = randint(0, len(movements) - 1)
        if rm_new != rm:
            rm = rm_new
            break

    rd = randint(min_seq, max_seq)

    print(f"{f'{(time.time() - start):.3f}': <6}", movements[rm].upper(), rm)
    time.sleep(rd)

print("finished")