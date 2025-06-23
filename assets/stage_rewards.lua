return function(level)
    local base = 10
    local bonus = math.floor(level / 5) * 5
    return {currency = "gold", amount = base + bonus}
end
