#Imports
import numpy as np
import pdb


# Systolic Array Dimensions
H=5
W=H
T=3*W+1



# Shift along axis
def shift(x, axis):
	padshape = x.shape[:]
	padshape = padshape[:axis]+(1,)+padshape[axis+1:]
	x        = np.concatenate([np.zeros(padshape, dtype=x.dtype), x], axis=axis)
	return x.swapaxes(0, axis)[:-1].swapaxes(0, axis)



# Simulate
if __name__ == "__main__":
	if True:
		#### Output-Stationary ####
		s  = np.zeros((H,   W),   dtype="float32")
		w  = np.zeros((H,   3*W), dtype="float32")
		d  = np.zeros((3*H, W  ), dtype="float32")
		A  = np.random.normal(size=(H,W)).astype("float32")
		B  = np.random.normal(size=(H,W)).astype("float32")
		
		# Skew the weights and data into lozenges
		for i in range(W):
			w[i,W-i-1:W-i-1+W]  = A[i]
		for i in range(H):
			d[H-i-1:H-i-1+H, i] = B[:, i]
		
		# Run time loop
		for t in range(T):
			#pdb.set_trace()
			# Do accumulation
			print("\n**** TIMESTEP", t, "****\nw:\n", np.round(8*w,0)/8, "\nd:\n", np.round(8*d,0)/8)
			s += w[:,-W:] * d[-H:,:]
			
			# Time-shift
			d = shift(d, 0)
			w = shift(w, 1)
			
			# Print
			print("\ns:\n", s)
		
		# Print true
		print("True:\n", A.dot(B))
	
	
	
	"""
		#### Row-Stationary ####
		s  = np.zeros((H,   4*W), dtype="float32")
		w  = np.zeros((3*H, W  ), dtype="float32")
		d  = np.zeros((3*H, W  ), dtype="float32")
		A  = np.random.normal(size=(H,W)).astype("float32")
		B  = np.random.normal(size=(H,W)).astype("float32")
		
		# Skew the weights and data into lozenges
		w[-2*W:-W] = A
		d[-2*W:-W] = B
		
		# Run time loop
		for t in xrange(3*W):
			#pdb.set_trace()
			# Do accumulation
			print "\n**** TIMESTEP", t, "****\nw:\n", np.round(8*w,0)/8, "\nd:\n", np.round(8*d,0)/8
			s[:,:W] += w[-W:,:] * d[-H:,:]
			
			# Time-shift
			d = shift(d, 0)
			w = np.roll(shift(w, 0), 1, axis=1)
			s = np.roll(s, 1, axis=1)
			
			# Print
			print "\ns:\n", s.T
		
		# Print true
		print "True:\n", B.dot(A)
	"""
