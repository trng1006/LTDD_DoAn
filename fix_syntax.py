with open('backend/main.py', 'r') as f:
    lines = f.readlines()

# delete lines 1754 to 1880 (0-indexed 1753 to 1879)
del lines[1753:1880]

with open('backend/main.py', 'w') as f:
    f.writelines(lines)
