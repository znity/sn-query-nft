%lang starknet

# A contract that allows us to query for the ownership of a ERC721 asset on the 
# underlying chain. This is useful for restricting some actions on L2 by 
# ownership of an asset on L1

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

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
    erc721_address: felt
):
    let (caller) = get_caller_address()
    owner_.write(caller)
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

@external
func set_721_address{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(address: felt):
    assert_not_zero(address)

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