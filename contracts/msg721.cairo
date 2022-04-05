%lang starknet

# A contract that allows us to query for the ownership of a ERC721 asset on the 
# underlying chain. This is useful for restricting some actions on L2 by 
# ownership of an asset on L1

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

@storage_var
func owner_() -> (owner: felt):
end

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

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}():
    let (caller) = get_caller_address()
    owner_.write(caller)
    return ()
end
