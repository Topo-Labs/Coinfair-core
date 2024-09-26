import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  CollectFee,
  LockLP,
  ReleaseLP,
  WithdrawFee
} from "../generated/CoinFairV2Treasury/CoinFairV2Treasury"

export function createCollectFeeEvent(
  token: Address,
  owner: Address,
  amount: BigInt,
  pair: Address
): CollectFee {
  let collectFeeEvent = changetype<CollectFee>(newMockEvent())

  collectFeeEvent.parameters = new Array()

  collectFeeEvent.parameters.push(
    new ethereum.EventParam("token", ethereum.Value.fromAddress(token))
  )
  collectFeeEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  collectFeeEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )
  collectFeeEvent.parameters.push(
    new ethereum.EventParam("pair", ethereum.Value.fromAddress(pair))
  )

  return collectFeeEvent
}

export function createLockLPEvent(
  pair: Address,
  locker: Address,
  amount: BigInt,
  lockTime: BigInt,
  isFirstTimeLock: boolean
): LockLP {
  let lockLpEvent = changetype<LockLP>(newMockEvent())

  lockLpEvent.parameters = new Array()

  lockLpEvent.parameters.push(
    new ethereum.EventParam("pair", ethereum.Value.fromAddress(pair))
  )
  lockLpEvent.parameters.push(
    new ethereum.EventParam("locker", ethereum.Value.fromAddress(locker))
  )
  lockLpEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )
  lockLpEvent.parameters.push(
    new ethereum.EventParam(
      "lockTime",
      ethereum.Value.fromUnsignedBigInt(lockTime)
    )
  )
  lockLpEvent.parameters.push(
    new ethereum.EventParam(
      "isFirstTimeLock",
      ethereum.Value.fromBoolean(isFirstTimeLock)
    )
  )

  return lockLpEvent
}

export function createReleaseLPEvent(
  pair: Address,
  releaser: Address,
  amount: BigInt
): ReleaseLP {
  let releaseLpEvent = changetype<ReleaseLP>(newMockEvent())

  releaseLpEvent.parameters = new Array()

  releaseLpEvent.parameters.push(
    new ethereum.EventParam("pair", ethereum.Value.fromAddress(pair))
  )
  releaseLpEvent.parameters.push(
    new ethereum.EventParam("releaser", ethereum.Value.fromAddress(releaser))
  )
  releaseLpEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return releaseLpEvent
}

export function createWithdrawFeeEvent(
  token: Address,
  owner: Address,
  amount: BigInt
): WithdrawFee {
  let withdrawFeeEvent = changetype<WithdrawFee>(newMockEvent())

  withdrawFeeEvent.parameters = new Array()

  withdrawFeeEvent.parameters.push(
    new ethereum.EventParam("token", ethereum.Value.fromAddress(token))
  )
  withdrawFeeEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  withdrawFeeEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return withdrawFeeEvent
}
