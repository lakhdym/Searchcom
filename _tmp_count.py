lines=open('lib/pages/my_listings_page.dart',encoding='utf8').read().splitlines()
count=0
for i,line in enumerate(lines,1):
    for ch in line:
        if ch=='(':
            count+=1
        elif ch==')':
            count-=1
    if count<0:
        print('negative at',i);break
    if count>0 and i>400:
        last=i
print('final',count)
