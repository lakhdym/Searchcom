text=open('lib/pages/my_listings_page.dart',encoding='utf8').read().splitlines()
count=0
last_plus=None
for i,line in enumerate(text,1):
    for ch in line:
        if ch=='(':
            count+=1; last_plus=i
        elif ch==')':
            count-=1
if count!=0:
    print('unbalanced, count',count,'last increment line',last_plus)
