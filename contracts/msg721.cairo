%lang starknet

# A contract that allows us to query for the ownership of a ERC721 asset on the 
# underlying chain. This is useful for restricting some actions on L2 by 
# ownership of an asset on L1

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_nn
from starkware.starknet.common.syscalls import get_caller_address 
from starkware.starknet.common.messages import send_message_to_l1

const PROVE_NFT_OWNERSHIP = 0
const L1_ADDRESS = 0x2Db8c2615db39a5eD8750B87aC8F217485BE11EC 

# TODO: change l1 address
# TODO: upload nft
# TODO: change storage naming convention


#	███████╗████████╗ ██████╗ ██████╗  █████╗  ██████╗ ███████╗
#	██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔══██╗██╔════╝ ██╔════╝
#	███████╗   ██║   ██║   ██║██████╔╝███████║██║  ███╗█████╗  
#	╚════██║   ██║   ██║   ██║██╔══██╗██╔══██║██║   ██║██╔══╝  
#	███████║   ██║   ╚██████╔╝██║  ██║██║  ██║╚██████╔╝███████╗
#	╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝

@storage_var
func owner_() -> (owner: felt):
end

@storage_var
func erc721_address() -> (address: felt):
end

# This structure would allow us to check the ownership of the right address
# even when erc721_address changes
@storage_var
func erc721_ownership(
    account: felt, 
    nft_address: felt, 
    nft_id: felt
) -> (
    is_owner: felt
):
end

#	 ██████╗███╗   ██╗███████╗████████╗ ██████╗ ██████╗ 
#	██╔════╝████╗  ██║██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗
#	██║     ██╔██╗ ██║███████╗   ██║   ██║   ██║██████╔╝
#	██║     ██║╚██╗██║╚════██║   ██║   ██║   ██║██╔══██╗
#	╚██████╗██║ ╚████║███████║   ██║   ╚██████╔╝██║  ██║
#	 ╚═════╝╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    erc721_address_: felt,
):
    let (caller) = get_caller_address()
    owner_.write(caller)

    erc721_address.write(erc721_address_)
    return ()
end

#	██╗   ██╗██╗███████╗██╗    ██╗
#	██║   ██║██║██╔════╝██║    ██║
#	██║   ██║██║█████╗  ██║ █╗ ██║
#	╚██╗ ██╔╝██║██╔══╝  ██║███╗██║
#	 ╚████╔╝ ██║███████╗╚███╔███╔╝
#	  ╚═══╝  ╚═╝╚══════╝ ╚══╝╚══╝ 

@view
func get_erc721_address{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}() -> (address: felt):
    return erc721_address.read()
end

@view
func is_owner{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(account: felt, id: felt) -> (result: felt):
    let (nft_address) = erc721_address.read()
    return erc721_ownership.read(
        account=account, 
        nft_address=nft_address, 
        nft_id=id
    )
end

#	███████╗██╗  ██╗████████╗███████╗██████╗ ███╗   ██╗ █████╗ ██╗     
#	██╔════╝╚██╗██╔╝╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔══██╗██║     
#	█████╗   ╚███╔╝    ██║   █████╗  ██████╔╝██╔██╗ ██║███████║██║     
#	██╔══╝   ██╔██╗    ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══██║██║     
#	███████╗██╔╝ ██╗   ██║   ███████╗██║  ██║██║ ╚████║██║  ██║███████╗
#	╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝

# Setters

@external
func set_721_address{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(address: felt):
    assert_not_zero(address)
    only_owner()

    return ()
end

# L1 Communication

@external
func query_nft_ownership{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(nft_id: felt):
    alloc_locals
    # Assert NFT ID is not negative
    assert_nn(nft_id)

    let (local nft_addr) = erc721_address.read() 
    let (local caller) = get_caller_address()

    let (send_payload: felt*) = alloc()
    assert send_payload[0] = PROVE_NFT_OWNERSHIP
    assert send_payload[1] = nft_addr
    assert send_payload[2] = nft_id
    assert send_payload[3] = caller

    send_message_to_l1(
        to_address=L1_ADDRESS,
        payload_size=4,
        payload=send_payload
    )

    return ()
end

@l1_handler
func set_owner_of{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    from_address: felt,
    nft_address: felt,
    nft_id: felt,
    owner_address: felt,
    is_owner: felt
):
    # Check if call source is legit
    assert from_address = L1_ADDRESS

    # Assign ownership
    erc721_ownership.write(
        account=owner_address,
        nft_address=nft_address,
        nft_id=nft_id,
        value=is_owner
    )
    return ()
end


#	██╗███╗   ██╗████████╗███████╗██████╗ ███╗   ██╗ █████╗ ██╗     
#	██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔══██╗██║     
#	██║██╔██╗ ██║   ██║   █████╗  ██████╔╝██╔██╗ ██║███████║██║     
#	██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══██║██║     
#	██║██║ ╚████║   ██║   ███████╗██║  ██║██║ ╚████║██║  ██║███████╗
#	╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝

# Allows functions to be called only by the owner of the contract
func only_owner{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    let (owner) = owner_.read()
    let (caller) = get_caller_address()
    with_attr error_message("Caller is not the owner"):
        assert owner = caller
    end
    return ()
end