lines=open('lib/pages/my_listings_page.dart',encoding='utf8').read().splitlines()
for i in range(len(lines)-12,len(lines)):
    print(f"{i+1}: {lines[i]}")
