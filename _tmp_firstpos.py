lines=open('lib/pages/my_listings_page.dart',encoding='utf8').read().splitlines()
count=0
flag=False
for i,line in enumerate(lines,1):
    for ch in line:
        if ch=='(':
            count+=1
        elif ch==')':
            count-=1
    if not flag and i>286 and count>0:
        print('first positive after 286 at',i,'count',count)
        flag=True
print('final',count)
