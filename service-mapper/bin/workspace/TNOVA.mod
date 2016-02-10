      # Copyright 2014-2016 Universita' degli studi di Milano
      #
      # Licensed under the Apache License, Version 2.0 (the "License");
      # you may not use this file except in compliance with the License.
      # You may obtain a copy of the License at
      #
      # http://www.apache.org/licenses/LICENSE-2.0
      #
      # Unless required by applicable law or agreed to in writing, software
      # distributed under the License is distributed on an "AS IS" BASIS,
      # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
      # See the License for the specific language governing permissions and
      # limitations under the License.
      #
      # -----------------------------------------------------
      #
      # Authors:
      #     Marco Trubian (marco.trubian@unimi.it)
      #     Alberto Ceselli (alberto.ceselli@unimi.it)
      #     Alessandro Petrini (alessandro.petrini@unimi.it)
      #
      # -----------------------------------------------------

      #
      # This finds the optimal solution to the optimal ILP TNOVA first level problem
      #

      /* sets */
      # Network Infrastructure Nodes (DC or PoP)
      set NInodes;
      # Network Infrastructure Links
      set NIlinks within (NInodes cross NInodes);
      # Virtual Network Functions Nodes
      set VNFnodes;
      # Virtual Network Functions Links
      set NSlinks within (VNFnodes cross VNFnodes);
      # Indices of Paths among VNFs with a delay constraint
      set IndexDelayPaths;
      # PD[IndexPath] = sequence of NSlinks
      set PD{path in IndexDelayPaths} within NSlinks;
      # Types of resources related to nodes (CPU, core, GPU, ...)
      set NT;
      # Types of resources related to links (Bandwidth, ...)
      set LT;

      /* parameters */
      param ResourceLinkCapacity {(p,q) in NIlinks, t in LT};
      param ResourceNodeCapacity {p in NInodes, t in NT};
      param ResourceLinkDemand {(h,k) in NSlinks, t in LT};
      param ResourceNodeDemand {h in VNFnodes, t in NT};
      param LinkDelay {(p,q) in NIlinks};
      param MaxDelay {path in IndexDelayPaths};
      param c{VNFnodes cross NInodes};
	  param alpha;
	  param beta;
	  param gamma;

	  param tot_cost := sum{h in VNFnodes}sum{p in NInodes} c[h,p];
	  param tot_delay := sum{path in IndexDelayPaths}sum{(h,k) in PD[path], (p,q) in NIlinks} LinkDelay[p,q];
	  param tot_linkusage := sum{(p,q) in NIlinks, t in LT}sum{(h,k) in NSlinks} ResourceLinkDemand[h,k,t];

	  param bound{VNFnodes cross NInodes};

      /* variables*/
      var x {NSlinks cross NIlinks}, binary;
      var y {VNFnodes cross NInodes}, binary;

      /* objective function */
      minimize min: alpha * (sum{h in VNFnodes}sum{p in NInodes} c[h,p]*y[h,p]) / tot_cost + beta * (sum{path in IndexDelayPaths}sum{(h,k) in PD[path], (p,q) in NIlinks} LinkDelay[p,q]*x[h,k,p,q]) / tot_delay + gamma * (sum{(p,q) in NIlinks, t in LT}sum{(h,k) in NSlinks} ResourceLinkDemand[h,k,t]*x[h,k,p,q]) / tot_linkusage;

      /* Constraints */
      /************** univoc VM assignment (2) ***********************************/
      s.t. VM_Map{h in VNFnodes}:
           sum{p in NInodes} y[h,p] = 1;
      /******************Flow Conservation Equations (3) *****************************/
      s.t. PathBalance{p in NInodes, (h,k) in NSlinks}:
           sum{(p,q) in NIlinks} x[h,k,p,q] - sum{(q,p) in NIlinks} x[h,k,q,p] = y[h,p] - y[k,p];
      /**************** Delay Constraints *********************************/
      s.t. DelayConst{path in IndexDelayPaths}:
           sum{(h,k) in PD[path], (p,q) in NIlinks} LinkDelay[p,q]*x[h,k,p,q] <= MaxDelay[path];
      /************** Capacity Constraints ***********************************/
      s.t. CapacityLink{(p,q) in NIlinks, t in LT}:
           sum{(h,k) in NSlinks} ResourceLinkDemand[h,k,t]*x[h,k,p,q] <= ResourceLinkCapacity[p,q,t];
      s.t. CapacityNode{p in NInodes, t in NT}:
           sum{h in VNFnodes} ResourceNodeDemand[h,t]*y[h,p] <= ResourceNodeCapacity[p,t];

	s.t. Bound{h in VNFnodes, p in NInodes}:
		y[h,p] >= bound[h,p];
    /*
    s.t. Inhibit{h in VNFnodes, p in NInodes}:
		y[h,p] <= inhibit[h,p];
    # default a 1
    # impostare a 0 per inibire allocazione di vnf in specifico PoP
    */
end;
