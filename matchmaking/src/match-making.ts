import {
  Like as LikeEvent,
  Match as MatchEvent,
  MultiSigCreated as MultiSigCreatedEvent
} from "../generated/MatchMaking/MatchMaking"
import { Like, Match, MultiSigCreated } from "../generated/schema"

export function handleLike(event: LikeEvent): void {
  let entity = new Like(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.liker = event.params.liker
  entity.target = event.params.target

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleMatch(event: MatchEvent): void {
  let entity = new Match(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.userA = event.params.userA
  entity.userB = event.params.userB

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleMultiSigCreated(event: MultiSigCreatedEvent): void {
  let entity = new MultiSigCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.walletAddress = event.params.walletAddress
  entity.userA = event.params.userA
  entity.userB = event.params.userB

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
