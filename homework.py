

# %%
# Class 1
import re

str1 = "This company is not good at all."
str2 = "I’m not at all happy about it"
# Method 1
def f1(s):
    return f"{s.split('not')[0]}good{s.split('at all')[1]}"

# Method 2
def f2(s): 
    return f"{s[:s.find('not')]}good{s[s.find('at all')+6:]}"

# Method 3
def f3(s):
    return re.sub(r"not.+?at all", "good", s)



print("Fn1: ", f1(str1)) # This company is good.
print("Fn1: ", f1(str2)) # I'm good happy about it

print("Fn2: ", f2(str1)) # This company is good.
print("Fn2: ", f2(str2)) # I'm good happy about it

print("Fn3: ", f3(str1)) # This company is good.
print("Fn3: ", f3(str2)) # I'm good happy about it

print("chris: ", re.sub("(not.+?at all)", "good", str1))
print("chris: ", re.sub("(not.+?at all)", "good", str2))
# %%
