import { newMockEvent } from "matchstick-as"
import { ethereum, Address } from "@graphprotocol/graph-ts"
import { Liked, Match } from "../generated/MatchMaking/MatchMaking"

export function createLikedEvent(liker: Address, target: Address): Liked {
  let likedEvent = changetype<Liked>(newMockEvent())

  likedEvent.parameters = new Array()

  likedEvent.parameters.push(
    new ethereum.EventParam("liker", ethereum.Value.fromAddress(liker))
  )
  likedEvent.parameters.push(
    new ethereum.EventParam("target", ethereum.Value.fromAddress(target))
  )

  return likedEvent
}

export function createMatchEvent(userA: Address, userB: Address): Match {
  let matchEvent = changetype<Match>(newMockEvent())

  matchEvent.parameters = new Array()

  matchEvent.parameters.push(
    new ethereum.EventParam("userA", ethereum.Value.fromAddress(userA))
  )
  matchEvent.parameters.push(
    new ethereum.EventParam("userB", ethereum.Value.fromAddress(userB))
  )

  return matchEvent
}
