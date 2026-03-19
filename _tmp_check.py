import re
text=open('lib/pages/my_listings_page.dart',encoding='utf8').read()
text=re.sub(r"\".*?\"|\'.*?\'",'',text)
stack=[]
for i,ch in enumerate(text):
    if ch in '({[':
        stack.append((ch,i))
    elif ch in ')}]':
        if not stack:
            print('Unmatched close',ch,'at',i); break
        o,pos=stack.pop()
        if '({['.index(o)!=')}]'.index(ch):
            print('Mismatch',o,'at',pos,'with',ch,'at',i)
            print('Stack tail:',stack[-5:])
            break
else:
    print('Balanced',len(stack))
