import {
  CollectFee as CollectFeeEvent,
  LockLP as LockLPEvent,
  ReleaseLP as ReleaseLPEvent,
  WithdrawFee as WithdrawFeeEvent
} from "../generated/CoinFairV2Treasury/CoinFairV2Treasury"
import { CollectFee, LockLP, ReleaseLP, WithdrawFee } from "../generated/schema"

export function handleCollectFee(event: CollectFeeEvent): void {
  let entity = new CollectFee(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.token = event.params.token
  entity.owner = event.params.owner
  entity.amount = event.params.amount
  entity.pair = event.params.pair

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleLockLP(event: LockLPEvent): void {
  let entity = new LockLP(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.pair = event.params.pair
  entity.locker = event.params.locker
  entity.amount = event.params.amount
  entity.lockTime = event.params.lockTime
  entity.isFirstTimeLock = event.params.isFirstTimeLock

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleReleaseLP(event: ReleaseLPEvent): void {
  let entity = new ReleaseLP(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.pair = event.params.pair
  entity.releaser = event.params.releaser
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleWithdrawFee(event: WithdrawFeeEvent): void {
  let entity = new WithdrawFee(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.token = event.params.token
  entity.owner = event.params.owner
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
