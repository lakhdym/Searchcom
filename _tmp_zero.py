lines=open('lib/pages/my_listings_page.dart',encoding='utf8').read().splitlines()
count=0
last_zero=0
for i,line in enumerate(lines,1):
    for ch in line:
        if ch=='(':
            count+=1
        elif ch==')':
            count-=1
    if count==0:
        last_zero=i
print('last zero at line',last_zero,'final count',count)
