import {
  Liked as LikedEvent,
  Match as MatchEvent
} from "../generated/MatchMaking/MatchMaking"
import { Liked, Match } from "../generated/schema"

export function handleLiked(event: LikedEvent): void {
  let entity = new Liked(
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
