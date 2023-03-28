from random import randint

string = '{'

for i in range(8):
    string += f'{hex(randint(0,2**32-1))},'

string = string[:-1] + '}'
print(string)
