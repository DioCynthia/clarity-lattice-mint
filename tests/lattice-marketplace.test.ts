import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can list and purchase NFT",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    // First mint an NFT
    let block = chain.mineBlock([
      Tx.contractCall("lattice-nft", "mint",
        [types.list([types.uint(1)]),
         types.list([types.uint(1)]),
         types.uint(2)],
        wallet_1.address
      )
    ]);
    
    // List the NFT
    block = chain.mineBlock([
      Tx.contractCall("lattice-marketplace", "list-token",
        [types.principal(wallet_1.address),
         types.uint(1),
         types.uint(1000000)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), true);
    
    // Purchase the NFT
    block = chain.mineBlock([
      Tx.contractCall("lattice-marketplace", "purchase",
        [types.principal(wallet_1.address),
         types.uint(1)],
        wallet_2.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectOk(), true);
  },
});
