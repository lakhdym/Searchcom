lines=open('lib/pages/my_listings_page.dart',encoding='utf8').read().splitlines()
count=0
for i,line in enumerate(lines[286:390],287):
    for ch in line:
        if ch=='(':
            count+=1
        elif ch==')':
            count-=1
    print(i,count,line)
print('block total',count)
