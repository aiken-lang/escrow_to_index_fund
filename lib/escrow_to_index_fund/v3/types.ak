use aiken/transaction.{OutputReference}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{AssetName, PolicyId}

pub type EscrowActionV3 {
  Unlock
  Update
  UpdatePastVersion
}

pub type EscrowRedeemV3 {
  action: EscrowActionV3,
  control_reference: OutputReference,
}

pub type Owner {
  Addr(Address)
  Nft(PolicyId, AssetName)
}

pub type EscrowStateV3 {
  tag: Data,
  owner: Owner,
  auto_update: Bool,
}
