# %%
import math
def test_functions(num: int = 5):
    print(f"this is a function !! value = {num}")
    return num ** 2
def fun2(r: int = 2) -> float:
    return r ** 2 * math.pi

a = test_functions(7)

print(f"a value = {a}")

print(f"圓面積 = {fun2()}")
# %%
def funcal(n1: int = 1, n2: int = 2) -> int:
    print (f"{n1} * {n2} = {n1 * n2}")

funcal(n1= 7, n2 = 2)
# %%
