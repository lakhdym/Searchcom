text=open("lib/pages/my_listings_page.dart",encoding="utf8").read().splitlines()
pos=8278
acc=0
for i,line in enumerate(text,1):
    acc+=len(line)+1
    if acc>=pos:
        print('line',i,'content',line)
        break
