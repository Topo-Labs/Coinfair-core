# Coinfair-core-v2

## How TO Deploy
1. DEPLOY treasury
2. DEPLOY factory, INPUT treasury,GET initcode
3. CHANGE the initcode in router
4. DEPLOY warmrouter AND DEPLOY hotrouter
5. USE setHotRouterAddress SETTING hotrouter IN factory
6. DEPLOY nft
7. USE setDEXAddress SETTING factory/nft IN treasury
