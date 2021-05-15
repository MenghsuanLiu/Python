

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
# Class 2
list1 = [1, 3, 1, 2, 2, 4, 5, 3]
list2 = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]

# Method 1
def f1(L):
    L = list(set(L))
    L.sort(reverse=True)
    return L

# Method 2
def f2(L):
    R = []
    for e in L:
        if e not in R:
            R.append(e)
    return sorted(R, reverse=True)

# Method 3
def f3(L):
  return sorted(dict.fromkeys(L).keys())[::-1]

print("Fn1: ", f1(list1)) # [5, 4, 3, 2, 1]
print("Fn1: ", f1(list2)) # [1]

print("Fn2: ", f2(list1)) # [5, 4, 3, 2, 1]
print("Fn2: ", f2(list2)) # [1]

print("Fn3: ", f3(list1)) # [5, 4, 3, 2, 1]
print("Fn3: ", f3(list2)) # [1]
# chris
print("chris: ", sorted(set(list1), reverse = True))
print("chris: ", sorted(set(list2), reverse = True))
# %%
from collections import Counter
# Class 3 
list1 = [1, 3, 1, 2, 2, 4, 5, 3]
list2 = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
# Method 1 
def f1(L):
  d = {}
  L2 = []
  for e in L:
    d[e] = d.get(e, 0) + 1
    if d[e] > 1 and e not in L2:
      L2.append(e)
  return L2

# Method 2
def f2(L):
  L2 = []
  for e in set(L):
    if L.count(e) > 1:
      L2.append(e)
  return L2

# Method 3
def f3(L):
  return [e for e in set(L) if L.count(e) > 1]

# Method 4
def f4(L):
  tmp = dict(Counter(L))
  return [k for (k,v) in tmp.items() if v > 1]

# Method 5
def f5(L):
  L.sort()
  return list(set(L[::2]) & set(L[1::2]))

def fn1(lst):
    set_list = set(lst)
    newlst = []
    newdict = {}
    for i in set_list:
        if lst.count(i) > 1:
            newlst.append(i)
            newdict[i] = lst.count(i)
    return sorted(newlst), newdict

def fn2(lst):
    dict_count = dict(Counter(lst))
    newlst = sorted([key for key, value in dict_count.items() if value > 1])
    newdict = {key:value for key,value in dict_count.items() if value > 1}
    return newlst, newdict
    
print("Fn1: ", f1(list1))
print("Fn1: ", f1(list2))
print("Fn2: ", f2(list1))
print("Fn2: ", f2(list2))
print("Fn3: ", f3(list1))
print("Fn3: ", f3(list2))
print("Fn4: ", f4(list1))
print("Fn4: ", f4(list2))
print("Fn5: ", f5(list1))
print("Fn5: ", f5(list2))
print("chris:", fn1(list1))
print("chris:", fn2(list1))
print("chris:", fn1(list2))
print("chris:", fn2(list2))
# %%
# Class 4
from collections import Counter
str1 = "Hello World"
# Method 1 
def f1(s):
  d = {}
  for c in s:
    if c not in d:
      d[c] = 0
    d[c] += 1
  return d

# Method 2
def f2(s):
  d = {}
  for c in s:
    d[c] = d.get(c, 0) + 1
  return d

# Method 3
def f3(s):
  d = {}
  for c in set(s):
    d[c] = s.count(c)
  return d

# Method 4
def f4(s):
  return dict((c, s.count(c)) for c in set(s))


def fn1(str):
  d = {}
  for e in str:
    d[e] = d.get(e, 0) + 1
  return d

def fn2(str):
    newdict = {}
    for i in set(str):
      newdict[i] = str.count(i)
    return newdict

def fn3(str):
    dict_count = dict(Counter(str))
    newdict = {key:value for key,value in dict_count.items()}
    return newdict


print("Fn1: ", f1(str1))
print("Fn2: ", f2(str1))
print("Fn3: ", f3(str1))
print("Fn4: ", f4(str1))
print("chris: ", fn1(str1))
print("chris: ", fn2(str1))
print("chris: ", fn3(str1))
dict(Counter(str1))
# %%
# Class 5
# Method 1
def f1(a, b):
  L = []
  for i in range(a, b+1):
    is_self_dividing = True
    tmp = int(i)
    while tmp != 0:
      n = tmp % 10
      if (n == 0) or (int(i) % n != 0):
        is_self_dividing = False
        break
      tmp = tmp // 10        
    if is_self_dividing:
      L.append(i)
  max_difference = 0
  for i in range(len(L)-1):
    if L[i+1] - L[i] > max_difference:
      answer = (L[i], L[i+1])
      max_difference = L[i+1] - L[i]
  return  answer
# Method 2
def f2a(n):
  is_self_dividing = True
  for c in str(n):
    if c == '0' or n % int(c) != 0:
      return False
  return True

def f2b(L):
  max_difference = 0
  for i in range(len(L)-1):
    if L[i+1] - L[i] > max_difference:
      answer = (L[i], L[i+1])
      max_difference = L[i+1] - L[i]
  return answer

def f2(a, b):
  return f2b([i for i in range(a, b+1) if f2a(i)])  

# Chris
def Fn(Lower, Upper):
    a = []
    dif = 0
    for num in range(int(Lower), int(Upper) + 1):
        if "0" in str(num):
            continue
        if (0 == sum(num % int(i) for i in str(num))) == True:
            a.append(num)
    

    for i,v in enumerate(a[:-1]):
        d = abs(v - a[i+1])#选择排序法，后面的元素减去前面的元素得到的值的绝对值为d
        if d > dif:
            first, second, dif = v, a[i+1], d
    result = [first, second]
    return result
print("Fn1: ", f1(100, 900))
print("Fn1: ", f1(11, 20))
print("Fn2: ", f2(100, 900))
print("Fn2: ", f2(11, 20))
print("chris: ", Fn(100, 900))
print("chris: ", Fn(11, 20))
# %%
# Class 6
lst = [1, 2, 3, 4, 5]

# Method 1
def add1(n):
  return n+1

def isPrime(n):
  for i in range(2, int(n**0.5)+1):
    if n % i == 0:
      return False
  return True

def f1(F, L):
  R = []
  for i in L:
    R.append(F(i))
  return R

# Method 1
def f2(F, L):
  return [F(i) for i in L]

# chris
def add1(n):
  return n + 1

def isPrime(n):
  prime = True
  if n > 1:
    for i in range(2, n):
        if (n % i) == 0:
            prime = False
            break
  return prime

def Fn1(func, *args):
    for i in zip(*args):
        yield func(*i)

print("Fn1: ", f1(add1, lst))
print("Fn1: ", f1(isPrime, lst))
print("Fn1: ", f2(add1, lst))
print("Fn1: ", f2(isPrime, lst))
print("chris: ", list(Fn1(add1, lst)))
print("chris: ", list(Fn1(isPrime, lst)))
# list(map(add1, lst))
# %%
