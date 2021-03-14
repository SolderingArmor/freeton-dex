# Free TON DEX

## Modules
* TTW_FT.sol - Ton Token Wallet, custom TIP-3 token wallet; CHANGES:
    * Has allowance mappings (for both addresses and public keys);
    * Has responsible functions for callbacks;
    * Some function names were changed for better understanding;
* RTW_FT.sol - Root Token Wallet, custom TIP-3 token root wallet; CHANGES:
    * Has responsible functions for callbacks;
* SymbolPair.sol - Pair pool for trading; FEATURES:
    * Deposit liquidity and earn interest (on fees);
    * Withdraw liquidity at any time;
    * Swap tokens;
* DexFactory.sol - DEX Factory that stores and manages all pairs/pools; FEATURES:
    * Add new Symbols; anyone can add a new Symbol, Symbol validity is verified by RTW callback;
    * Add new Symbol Pairs; anyone can add a new SymbolPair if it doesn't exist;
* DexDebot.sol - DexFactory DeBot;

## Testing
Check "tests/get_url.sh" and adjust to point to your TON OS SE;
Run the following command to deploy all the contracts:
```
cd tests
./_deploy_all.sh
```

It will deploy: 
* RTW1 (Shilo) with "keysRTW1.json" and 5 TTW1 with keys "keys[1-5].json"
* RTW1 (Mylo) with "keysRTW2.json" and 5 TTW2 with keys "keys[1-5].json"
* DexFactory;
After that it will add both RTWs to Symbols of the DexFactory;
Then it will add SymbolPair "Shylo-Mylo" to DexFactory;

Run the followng command to perform testing:
```
cd tests
./_test_pair.sh
```

It will:
1. Show current Symbols of the Pair;
2. Get current fee of the Pair;
3. Give allowance to SymbolPair to spend tokens of TTW1 and TTW2;
4. Deposit liquidity using TTW1 and TTW2;
5. Get ratio between two Symbols (1/2 and then 2/1);
6. Get Pair liquidity: total, for all users and for owner of TTW1 and TTW2;
7. Get price of both Symbols;
8. Perform Swap operation;
9. Get upadted Pair liquidity;
10. Withdraw liquidity;
11. Get upadted Pair liquidity;