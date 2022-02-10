#!/usr/bin/env julia

using ACE1pack, ArgParse
parser = ArgParseSettings(descirption="Fit an ACE potential from parameters file")
@add_arg_table parser begin
    "--fit-params", "-p"
        help = "A JSON filename with parameters for the fit"
    "--dry-run"
        help = "Only quickly compute various sizes, etc"
        action = :store_true
end

get_basis_size(d::Dict) = 
    sum([length(ACE1pack.generate_basis(basis_params)) for (basis_name, basis_params) in d])

function get_num_observations(d::Dict)
    # doesn't work properly somehow
    data = ACE1pack.read_data(d)    
    n_obs = 0
    for (okey, d, _) in IPFitting.observations(data)
        len = length(IPFitting.observation(d, okey))
        global n_obs += len
     end
     return 
end

function save_dry_run_info(fit_params)
    num_observations = get_num_observations(fit_params["data"])
    basis_size = get_basis_size(fit_params["basis"])
    dry_fit_filename = fit_params["ACE_fname_stem"] * ".size"
    size_info = Dict("lsq_matrix_shape" => (num_observations, basis_size))
    save_json(dry_fit_filename, size_info)
    exit(0)
end

if haskey(ENV, "ACE_FIT_BLAS_THREADS")
    nprocs = parse(Int, ENV["ACE_FIT_BLAS_THREADS"])
    @warn "Using $nprocs threads for BLAS"
    BLAS.set_num_threads(nprocs)
end

args = parse_args(parser)
fit_params = fill_defaults!(load_dict(args["fit_params"]))

if args["dry-run"]
    save_dry_run_info(fit_params)
end

# TODO: ACE_FIT_BLAS_THREADS??
ACE1pack.fit_ace(fit_params)





