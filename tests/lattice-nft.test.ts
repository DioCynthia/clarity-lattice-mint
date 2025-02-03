import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can mint new lattice NFT with valid parameters",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const points = [1,2,3,4];
    const connections = [1,2];
    const dimensions = 2;
    
    let block = chain.mineBlock([
      Tx.contractCall("lattice-nft", "mint", 
        [types.list(points.map(p => types.uint(p))),
         types.list(connections.map(c => types.uint(c))),
         types.uint(dimensions)], 
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    assertEquals(block.receipts[0].result.expectOk(), "u1");
  },
});

Clarinet.test({
  name: "Cannot mint with invalid parameters",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("lattice-nft", "mint",
        [types.list([]),
         types.list([]),
         types.uint(1)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result.expectErr(), "u102");
  },
});
