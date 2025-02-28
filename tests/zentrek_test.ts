import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create new exercise",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('zentrek', 'create-exercise',
        [
          types.ascii("Ocean Breaths"),
          types.ascii("Ocean Waves"),
          types.uint(300)
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    block.receipts[0].result.expectOk().expectUint(1);
  },
});

Clarinet.test({
  name: "Can complete exercise and update stats",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // First create an exercise
    let block = chain.mineBlock([
      Tx.contractCall('zentrek', 'create-exercise',
        [
          types.ascii("Forest Walk"),
          types.ascii("Bird Songs"),
          types.uint(600)
        ],
        deployer.address
      )
    ]);
    
    // Complete the exercise
    block = chain.mineBlock([
      Tx.contractCall('zentrek', 'complete-exercise',
        [types.uint(1)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Check updated stats
    const statsResponse = chain.callReadOnlyFn(
      'zentrek',
      'get-user-stats',
      [types.principal(deployer.address)],
      deployer.address
    );
    
    const stats = statsResponse.result.expectOk().expectSome();
    assertEquals(stats['exercises-completed'], types.uint(1));
    assertEquals(stats['streak'], types.uint(1));
  },
});

Clarinet.test({
  name: "Cannot complete non-existent exercise",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('zentrek', 'complete-exercise',
        [types.uint(999)],
        wallet1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectErr().expectUint(100);
  },
});
