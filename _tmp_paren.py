text=open('lib/pages/my_listings_page.dart',encoding='utf8').read().splitlines()
count=0
for i,line in enumerate(text,1):
    for ch in line:
        if ch=='(':
            count+=1
        elif ch==')':
            count-=1
    if count<0:
        print('negative at line',i); break
else:
    print('final count',count)
