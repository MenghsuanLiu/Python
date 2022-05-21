from vnpy.trader.constant import Direction


def get_minimum_tick(cost):

    if cost < 10:
        return 0.01
    elif cost < 50:
        return 0.05
    elif cost < 100:
        return 0.1
    elif cost < 500:
        return 0.5
    elif cost < 1000:
        return 1
    else:
        return 5


def get_commission(cost, multiplier, qty, direction):

    commission = cost * multiplier * qty * (0.1425 / 100)
    commission = commission * 0.3
    commission = 20 if commission < 20 else commission

    if direction == Direction.SHORT:

        fee = cost * multiplier * qty * (0.3 / 100)
        fee = fee / 2

        return commission + fee

    else:
        return commission


