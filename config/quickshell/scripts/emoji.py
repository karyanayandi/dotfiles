import sys,re,json
out=[]
for l in sys.stdin:
    m=re.match(r'^([0-9A-F ]+)\s*;\s*fully-qualified\s*#\s*(\S+)\s+E[\d.]+\s+(.+)$', l)
    if m:
        out.append({"e":m[2],"n":m[3].strip()})
print(json.dumps(out,ensure_ascii=False))
