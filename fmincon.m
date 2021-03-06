## Copyright (C) 2015 Asma Afzal
##
## Octave is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or (at
## your option) any later version.
##
## Octave is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {} fmincon (@var{fun}, @var{x0}, @var{A}, @var{b})
## @deftypefn {Function File} {} fmincon (@var{fun}, @var{x0}, @var{A}, @var{b}, @var{Aeq}, @var{beq})
## @deftypefnx {Function File} {} fmincon (@var{fun}, @var{x0}, @var{A}, @var{b}, @var{Aeq}, @var{beq}, @var{lb}, @var{ub})
## @deftypefnx {Function File} {} fmincon (@var{fun}, @var{x0}, @var{A}, @var{b}, @var{Aeq}, @var{beq}, @var{lb}, @var{ub}, @var{nonlcon})
## @deftypefnx {Function File} {} fmincon (@var{fun}, @var{x0}, @var{A}, @var{b}, @var{Aeq}, @var{beq}, @var{lb}, @var{ub}, @var{nonlcon}, @var{options})
## @deftypefnx {Function File} {[@var{x}, @var{fval}, @var{exitflag}, @var{output}, @var{lambda}, @var{grad}, @var{hessian}] =} fmincon (@dots{})
## Find minimum of nonlinear constrained scalar objective function
## @example
## @group
## min f(x)
##  x
## @end group
## @end example
## subject to
## @example
## @group
## @var{A}*@var{x} <= @var{b},
## @var{Aeq}*@var{x} = @var{beq},
## @var{lb} <= @var{x} <= @var{ub},
## @code{c(x)} <= 0,
## @code{ceq(x)} <= 0.
## @end group
## @end example
##
## @var{fun} is the scalar objective function to be minimized. @var{A} and @var{Aeq} are the linear constraint matrices and @var{b} and @var{beq}
## are the corresponding vectors. @var{nonlcon} is the function computing the nonlinear inequality and equality constraints. This function accepts
## the vector @var{x} as input and gives the two output vectors @var{c(x)} and @var{ceq(x)}.
## @var{options} is a structure containing estimation algorithm options. It can be set using @code{optimset}. If the option @code{GradObj} is set to
## @code{on}, @var{fun} must return a second output argument containing the gradient vector, @code{g(x)}. If the option @code{Hessian} is set to
## @code{user-supplied}, @var{fun} must return a third output argument containing the hessian matrix, @code{h(x)}. If the option @code{GradConstr} is set to
## @code{on}, @var{nonlcon} must also return, in the third and fourth output arguments, GC, the gradient of c(x), and GCeq, the gradient of ceq(x).
##
## Returned values:
##
## @table @var
## @item x
## Position of minimum.
##
## @item fval
## Scalar value of objective at the minimum.
##
## @item exitflag
## Status of solution:
##
## @table @code
## @item 0
## Maximum number of iterations reached.
##
## @item 1
## Solution x found.
##
## @item 2
## Change in x was less than the specified tolerance.
##
## @item 3
## Change in the objective function was less than the specified tolerance.
##
## @item -1
## Output function terminated the algorithm.
## @end table
##
## @item output
## Structure with additional information, currently the only field is
## @code{iterations}, the number of used iterations.
##
## @item lambda
## Structure containing Lagrange multipliers at the solution @var{x} sepatared by constraint type.
##
## @item gradient
## Vector, where @var{gradient(i)} is the partial derivative of @var{fun} with respect to @var{x(i)}
## As a default, fmincon approximates the Jacobian using finite differences.
##
## @item hessian
## Symmetric matrix of second derivative of the Lagrangian.
##
## @end table
##
## This function is a compatibility wrapper. It calls the more general @code{nonlin_min} function internally.
## @end deftypefn

## PKG_ADD: __all_opts__ ("fmincon");

function varargout = fmincon (modelfun, x0, varargin)
  nargs = nargin ();

  TolFun_default = 1e-6;
  MaxIter_default = 400;
  TypicalX_default = 1;

  if (nargs == 1 && ischar (modelfun) && strcmp (modelfun, "defaults"))
    varargout{1} = optimset ("FinDiffRelStep", [],...
               "FinDiffType", "forward",...
               "TypicalX", TypicalX_default,...
               "TolFun", TolFun_default,...
               "TolX",[],...
               "MaxIter", MaxIter_default,...
               "Display", "off",...
               "GradObj", "off",...
               "Hessian", "dfdp",...
               "OutputFcn", {}, ...
               "GradConstr", "off",...
               "Algorithm", "lm_feasible");
    return;
  endif

  if (nargs < 4 || nargs == 5  || nargs == 7  || nargs > 10)
    print_usage ();
  endif

  out_args = nargout ();
  varargout = cell (1, out_args);
  in_args(1:2) = {modelfun, x0};
  inequc = cell(1,4);
  equc = cell(1,4);
  settings = struct ();
  ## linear constraints are specified in a different way for nonlin_min
  ineq_index = 1;
  if (~ isempty (varargin{1}) && ~ isempty (varargin{2}) )
     inequc(1:2) = {-1 * varargin{1}.', varargin{2}};
     ineq_index = 3;
  end

  if (nargs >=6)
     eq_index = 1;
     if (~ isempty (varargin{3}) && ~ isempty (varargin{4}) )
        equc(1:2) = {-1 * varargin{3}.', varargin{4}};
        eq_index = 3;
     end
  endif

  if (nargs >= 8)
     ## bounds are specified in a different way for nonlin_min
     settings = optimset ("lbound", varargin{5}(:),
                         "ubound", varargin{6}(:));
  endif

  if (nargs >= 9)
     if (~ isempty (varargin{7}))
        nonlcon = varargin{7};
        inequc{ineq_index} = @(p) -1 * computeC (nonlcon, p);
        equc{eq_index} = @(p) computeCeq (nonlcon, p);
     endif
  endif

  if (nargs == 10)
    ## Jacobian function is specified in a different way for
    ## nonlin_min
    settings = struct ();
    if (strcmpi (optimget (varargin{8}, "GradObj"), "on"))
      settings = optimset (settings,
                       "objf_grad", @(p) computeGrad (modelfun, p));
    endif
    ## Hessian function is specified in a different way for
    ## nonlin_min
    Hessian = optimget (varargin{8}, "Hessian");
    if (strcmpi (Hessian, "user-supplied") || strcmpi (Hessian, "on"))
      settings = optimset (settings,
                       "objf_hessian", @(p) computeHess (modelfun, p));
    endif
    ## Hessian function is specified in a different way for
    ## nonlin_min
    if (any (strcmp (fieldnames (nonlin_min ("defaults")), "GradConstr")) &&...
    strcmpi (optimget (varargin{8}, "GradConstr"), "on"))
      equc{4} = @(p) computeGC (modelfun, p);
      inequc{4} =  @(p) computeGCeq (modelfun, p);
    endif
     ## apply default values which are possibly different from those of
     ## nonlin_min
     FinDiffType = optimget (varargin{8}, "FinDiffType", "forward");
     if (strcmpi (FinDiffType, "forward"))
       FinDiffRelStep_default = sqrt (eps);
     elseif (strcmpi (FinDiffType, "central"))
       FinDiffRelStep_default = eps^(1/3);
     else
       error ("unknown value of option 'FinDiffType': %s",
               FinDiffType);
     endif
     FinDiffRelStep = optimget (varargin{8}, "FinDiffRelStep", FinDiffRelStep_default);
     TolFun = optimget (varargin{8}, "TolFun", TolFun_default);
     MaxIter = optimget (varargin{8}, "MaxIter", MaxIter_default);
     TypicalX = optimget (varargin{8}, "TypicalX", TypicalX_default);
     Display = optimget (varargin{8}, "Display", "off");
     if (! iscell (OutputFcn = optimget (varargin{8}, "OutputFcn", {})))
       OutputFcn = {OutputFcn};
     endif

     if (! strcmpi (Display, "off"))
       if (strcmpi (Display, "iter-detailed") || strcmpi (Display, "final")...
       || strcmpi (Display, "final-detailed"))
           Display = "iter";
       endif
     endif
     ## 'user_interaction' must return an additional informational
     ## output argument
     user_interaction = compute_user_interaction (OutputFcn);

     settings = optimset (settings,
                           "FinDiffRelStep", FinDiffRelStep,
                           "FinDiffType", FinDiffType,
                           "TolFun", TolFun,
                           "TypicalX", TypicalX,
                           "MaxIter", MaxIter,
                           "Display", Display,
                           "Algorithm", "lm_feasible",
                           "user_interaction", user_interaction);
  endif

  if ( out_args >= 6)
    if (any (strcmp (fieldnames (nonlin_min ("defaults")), "ret_objf_grad")) &&...
    any (strcmp (fieldnames (nonlin_min ("defaults")), "ret_hessian")))
      settings = optimset (settings, "ret_objf_grad", true,
                           "ret_hessian", true);
    endif
  endif

  settings = optimset (settings, "inequc", inequc, "equc", equc);

  in_args{3} = settings;

  n_out = max (1, min (out_args, 4));

  min_out = cell (1, n_out);

  [min_out{:}] =  nonlin_min (in_args{:});

  varargout{1} = min_out{1};

  if (out_args >= 2)
    varargout{2} = min_out{2};
  endif

  if (out_args >= 3)
    varargout{3} = min_out{3};
  endif

  if (out_args >= 4)
    outp = min_out{4};
    if (isfield (outp,"lambda"))
      outp = rmfield (outp, "lambda");
      if (out_args >= 5 && isstruct (min_out{4}.lambda))
        varargout{5} = min_out{4}.lambda;
      endif
    endif
    if (isfield (outp, {"objf_grad", "hessian"}))
      outp = rmfield (outp, {"objf_grad", "hessian"});
      if (out_args >= 6)
        varargout{6} = min_out{4}.objf_grad;
      endif
      if (out_args >= 7)
        varargout{7} = min_out{4}.hessian;
      endif
    endif
    varargout{4} = outp;
  endif

  endfunction

function user_interaction = compute_user_interaction (OutputFcn)
  n = numel (OutputFcn);
  user_interaction = cell (1, n);
  for i = 1:n;
    user_interaction{i} = @(p, vals, state) deal (OutputFcn{i} (p, vals, state), {} ) ;
  endfor
endfunction

 function Grad = computeGrad (modelfun, p)
  [~, Grad] = modelfun (p);
endfunction

function Hess = computeHess (modelfun, p)
  [~, ~, Hess] = modelfun (p);
endfunction

function C = computeC (nonlcon, p)
 [C, ~] = nonlcon (p);
endfunction

function Ceq = computeCeq (nonlcon, p)
 [~, Ceq] = nonlcon (p);
endfunction

function GC =  computeGC (nonlcon, p)
  [~, ~, GC] = nonlcon (p);
endfunction

function GCeq =  computeGCeq (nonlcon, p)
  [~, ~, ~, GCeq] = nonlcon (p);
endfunction

%!test
%!  c = @(x)[x(1) ^ 2 / 9 + x(2) ^ 2 / 4 - 1;
%!          x(1)^2 - x(2) - 1];
%!  ceq = @(x) tanh (x(1)) - x(2);
%!  nonlinfcn = @(x) deal (c(x), ceq(x));
%!  obj = @(x) cosh (x(1)) + sinh (x(2));
%!  z = fmincon (obj,[0;0],[],[],[],[],[],[],nonlinfcn);
%!  assert(z, [-0.65256;-0.57339], 1e-2)

%!demo
%!  function [c,ceq,gc,gceq]=nonlcon(x)
%!  %% Non-linear inequality constraint
%!  c=[];
%!  %% Non-linear equality constraint
%!  ceq=x(1) * x(2) - 8 - 2 / 3 - 2 / 9;
%! %% Gradient of non-linear inequality constraint
%!  gc=[];
%! %% Gradient of non-linear equality constraint
%!  gceq=[x(2); x(1)];
%!  endfunction
%!
%!  objf = @(x) - x(1) * x(2) ^ 2 * x(3) ^ 3 * x(4) ^ 4;
%!  %% Initial guess
%!  x0 = [2.5;2.5;2.5;2.5];
%!  %% Linear equality constraints
%!  Aeq = [1, 1, 1, 1; 1, 1, -1, -1];
%!  beq = [10;0];
%!  %% Bound constraints
%!  lb = [0;0;0;0];
%!  ub = [10;10;10;10];
%!  [x,fval,flag,output,lambda,gradient,hessian] = fmincon(f, x0, [], [], Aeq, beq, lb, ub, @nonlcon)