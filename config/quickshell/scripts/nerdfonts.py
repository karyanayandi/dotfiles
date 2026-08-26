import sys,json
g=json.load(sys.stdin)
g.pop("METADATA",None)
print(json.dumps([{"c":chr(int(v["code"],16)),"n":k,"k":" ".join(v.get("tags",[]))} for k,v in g.items() if v.get("code")],ensure_ascii=False))
