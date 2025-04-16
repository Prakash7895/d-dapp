import { newMockEvent } from "matchstick-as"
import { ethereum, Address } from "@graphprotocol/graph-ts"
import {
  Like,
  Match,
  MultiSigCreated
} from "../generated/MatchMaking/MatchMaking"

export function createLikeEvent(liker: Address, target: Address): Like {
  let likeEvent = changetype<Like>(newMockEvent())

  likeEvent.parameters = new Array()

  likeEvent.parameters.push(
    new ethereum.EventParam("liker", ethereum.Value.fromAddress(liker))
  )
  likeEvent.parameters.push(
    new ethereum.EventParam("target", ethereum.Value.fromAddress(target))
  )

  return likeEvent
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

export function createMultiSigCreatedEvent(
  walletAddress: Address,
  userA: Address,
  userB: Address
): MultiSigCreated {
  let multiSigCreatedEvent = changetype<MultiSigCreated>(newMockEvent())

  multiSigCreatedEvent.parameters = new Array()

  multiSigCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "walletAddress",
      ethereum.Value.fromAddress(walletAddress)
    )
  )
  multiSigCreatedEvent.parameters.push(
    new ethereum.EventParam("userA", ethereum.Value.fromAddress(userA))
  )
  multiSigCreatedEvent.parameters.push(
    new ethereum.EventParam("userB", ethereum.Value.fromAddress(userB))
  )

  return multiSigCreatedEvent
}
