import xml.etree.ElementTree as ET

SKIP_PROPERTIES = {
    "SourceAssetId",
    "Tags",
    "LocalizationMatchIdentifier",
    "LocalizationMatchedSourceText",
    "AttributesSerialize",
    "Capabilities",
    "DefinesCapabilities",
    "RootLocalizationTable",
    "HoverHapticEffect",
    "HoverImage",
    "PressHapticEffect",
    "PressedImage",
    "ResetOnSpawn",
}

BASE_W = 1920
BASE_H = 1080

BASE_UDIM = 1000

index = 0
lines = []


def prop_value(node):
    tag = node.tag
    val = (node.text or "").strip()
    if tag in {"string", "BinaryString", "Content"}:
        return repr(val)
    if tag == "bool":
        return "true" if val == "true" else "false"
    if tag in {"int", "int64", "float", "double", "token"}:
        return val
    if tag == "Ref":
        return "nil"
    if tag == "Vector2":
        x = y = "0"
        for c in node:
            if c.tag == "X":
                x = c.text or "0"
            elif c.tag == "Y":
                y = c.text or "0"
        return f"Vector2.new({x},{y})"
    if tag == "UDim2":
        xs = xo = ys = yo = 0.0
        for c in node:
            if c.tag in ("XS", "XScale"):
                xs = float(c.text or 0)
            elif c.tag in ("XO", "XOffset"):
                xo = float(c.text or 0)
            elif c.tag in ("YS", "YScale"):
                ys = float(c.text or 0)
            elif c.tag in ("YO", "YOffset"):
                yo = float(c.text or 0)
        xs = xs + xo / BASE_W
        ys = ys + yo / BASE_H
        return f"UDim2.fromScale({xs},{ys})"
    if tag == "Color3":
        r = g = b = 0.0
        for c in node:
            if c.tag == "R":
                r = float(c.text or 0)
            elif c.tag == "G":
                g = float(c.text or 0)
            elif c.tag == "B":
                b = float(c.text or 0)
        return f"Color3.new({r},{g},{b})"
    if tag == "UDim":
        s = o = 0.0
        for c in node:
            if c.tag in ("S", "Scale"):
                s = float(c.text or 0)
            elif c.tag in ("O", "Offset"):
                o = float(c.text or 0)
        s = s + o / BASE_UDIM
        return f"UDim.new({s},0)"
    if tag == "Font":
        family = ""
        weight = 400
        style = "Normal"
        for c in node:
            if c.tag == "Family":
                family = ""
                for sub in c:
                    if sub.tag.lower() == "url":
                        family = (sub.text or "").strip()
                        break
            elif c.tag == "Weight":
                try:
                    weight = int(c.text or 400)
                except ValueError:
                    weight = 400
            elif c.tag == "Style":
                style = (c.text or "Normal").strip()
        weight_enum = "Enum.FontWeight.Regular"
        if weight >= 700:
            weight_enum = "Enum.FontWeight.Bold"
        style_enum = f"Enum.FontStyle.{style}"
        return f"Font.new({repr(family)}, {weight_enum}, {style_enum})"
    if tag == "Rect2D":
        min_x = min_y = max_x = max_y = 0
        for c in node:
            if c.tag == "min":
                for m in c:
                    if m.tag == "X":
                        min_x = int(m.text or 0)
                    elif m.tag == "Y":
                        min_y = int(m.text or 0)
            elif c.tag == "max":
                for m in c:
                    if m.tag == "X":
                        max_x = int(m.text or 0)
                    elif m.tag == "Y":
                        max_y = int(m.text or 0)
        return f"Rect.new({min_x},{min_y},{max_x},{max_y})"
    return repr(val)


def gen_item(item, parent):
    global index
    if item.tag != "Item":
        return
    index += 1
    var = f"obj{index}"
    lines.append(f"    local {var} = Instance.new(\"{item.attrib['class']}\")")
    for child in item:
        if child.tag == "Properties":
            for p in child:
                prop_name = p.attrib.get('name')
                if not prop_name or prop_name in SKIP_PROPERTIES:
                    continue
                lines.append(f"    {var}.{prop_name} = {prop_value(p)}")
        elif child.tag == "Item":
            gen_item(child, var)
    if parent:
        lines.append(f"    {var}.Parent = {parent}")
    if item.attrib.get('class') == "TextLabel":
        corner = f"corner{index}"
        lines.append(f"    local {corner} = Instance.new(\"UICorner\")")
        lines.append(f"    {corner}.CornerRadius = UDim.new(0.05,0)")
        lines.append(f"    {corner}.Parent = {var}")


def main():
    tree = ET.parse('gui.rbxmx')
    root = tree.getroot()
    first_item = None
    for child in root:
        if child.tag == 'Item':
            first_item = child
            break
    if first_item is None:
        raise RuntimeError('No Item found in gui.rbxmx')
    lines.append("local function createGui(parent)")
    lines.append("    local screenGui = Instance.new(\"ScreenGui\")")
    for child in first_item:
        if child.tag == "Properties":
            for p in child:
                prop_name = p.attrib.get('name')
                if not prop_name or prop_name in SKIP_PROPERTIES:
                    continue
                if prop_name == "Name":
                    lines.append("    screenGui.Name = \"InventoryUI\"")
                else:
                    lines.append(f"    screenGui.{prop_name} = {prop_value(p)}")
        elif child.tag == "Item":
            gen_item(child, "screenGui")
    lines.append("    screenGui.IgnoreGuiInset = true")
    reset_val = None
    for child in first_item:
        if child.tag == "Properties":
            for p in child:
                if p.attrib.get('name') == "ResetOnSpawn":
                    reset_val = (p.text or "").strip()
                    break
    if reset_val != "false":
        lines.append("    screenGui.ResetOnSpawn = false")
    lines.append("    if parent then screenGui.Parent = parent end")

    lines.append("    return screenGui")
    lines.append("end")
    lines.append("return createGui")

    with open('src/GeneratedGui.lua', 'w') as f:
        f.write("\n".join(lines))


if __name__ == '__main__':
    main()
