/*
Copyright (c) 2014 Lawrence Angrave
Version 0.1.1
All Rights Reserved.

This source code is provided and licensed under the "Angrave Open Relicense (NCSA-Version)" license defined below:
This code is licensed under the University of Illinois/NCSA Open Source License (http://opensource.org/licenses/NCSA)
This code may be re-licensed under an open source license that is approved and recognized by the Open Source Initiative (http://opensource.org/)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

If you use this code, an acknowledgement and link back to this project (https://github.com/angrave/tealeaves/) would be appreciated.
*/

function RingBuffer(allocfn) {
  if(allocfn) this._new_array = allocfn;
  
  this.reset();
}

// Reset the RingBuffer to be empty and small. The current storage object is discarded.
RingBuffer.prototype.reset = function (){
  // Code uses the lowest bits of this.begin, this.end i.e. always bitwise-and with this.array.length

  this.begin = 0x0; // First valid entry in the Ring buffer
  this.end = 0x0; // Position of the next free position at the end of the Ring buffer.
  this.length = 0x0;
  
  this._shrink_count = 0x0; // Only used to verify test coverage
  this.min_capacity = 128; // smallest capacity that the buffer will shrink to

  this.array = this._new_array(0x10);
  this.empty_value = this.array[0]; // Useful to remove object pointers.
}

// Creates the storage array. Overload this method (or pass a function into the ctor) to use a different storage class.
// This method is called whenever the RingBuffer needs a new storage object.
RingBuffer.prototype._new_array = function(size) {
  return new Array(size);
}
// Internal use only. Use a new storage array of length 'size'
// If 'size' is too small this function is a NOOP.
RingBuffer.prototype._realloc = function (size) {
  var len = this.length;
  if(len > size) return; //sanity check
  
  var old = this.array;

  this.array = this._new_array(size); 

  // Copy values upto the end of the old array
  var i = 0x0, j = this.begin;
  var wrap = Math.min( len, old.length - j ) ;
  while(i < wrap)
     this.array[ i++ ] = old[ j++ ];

  // Copy values that wrapped around
  j = 0;
  while(i < len)
    this.array[ i++ ] = old[ j++ ];

  
  this.begin = 0x0;
  this.end = len;
}
// Internal method used by push() and unshift()
RingBuffer.prototype._check_grow = function() {
  if( this.length == this.array.length)
     this._realloc( this.length << 1 );
}

// Internal method used by pop() and shift()
RingBuffer.prototype._check_shrink = function() {
  // We assume that the ringbuffer may be filled again in the near future and re-allocation is expensive
  // so we are reluctant to shrink the buffer capacity
  // Also, when we do shrink, we ensure the buffer is no more than half full
  var candidate_size = this.array.length >> 2; // If we shrink we will quarter our size
  if( this.length <= (candidate_size>>1) && candidate_size >= this.min_capacity  ) {
    this._shrink_count++;
    this._realloc(  candidate_size ); 
  }
}

// Public 'Array'-like methods:

// No error checking. Assumes 0<= index < this.length
RingBuffer.prototype.get = function (index) {
  return this.array[ (this.begin + index ) % this.array.length ];
}

// Adds to the end of the buffer. Returns the new length of the buffer.
RingBuffer.prototype.push = function (value) {
  this._check_grow();
  
  this.array[ this.end ] = value;
  this.end = (this.end + 1) % this.array.length;
  return ++ this.length;
}

// Adds to the beginning of the buffer. Returns the new length of the buffer.
RingBuffer.prototype.unshift = function (value) {
  this._check_grow();
  
  this.begin = (this.begin + this.array.length - 1) % this.array.length;
  this.array[ this.begin ] = value;

  return ++ this.length;  
}

// Removes (and returns) the last item in the buffer.
RingBuffer.prototype.pop = function () {
  if(this.length === 0) 
    return;
    
  this._check_shrink();
  
  -- this.length;
  this.end = (this.end + this.array.length - 1) % this.array.length;
  
  var result = this.array[ this.end ];
  this.array[ this.end ] = this.empty_value;
  return result;
}

// Removes (and returns) the first item in the buffer.
RingBuffer.prototype.shift = function () {
  if(this.length === 0) 
    return;
    
  this._check_shrink();
    
  -- this.length;
  var result = this.array[ this.begin ];
  
  this.array[ this.begin ] = this.empty_value;
  
  this.begin = (this.begin + 1) % this.array.length;
  
  return result;
}


// Returns a string representation of the ringbuffer.
RingBuffer.prototype.join = function(sep) {
  
  if(arguments.length ==0)
    sep = ",";
  
  var len = this.length;

  var result = len > 0 ? this.get(0) : "";
  for(var i = 1; i < len; i++)
    result += sep + this.get(i);
    
  return result;
}
// Returns a string representation of the buffer.
RingBuffer.prototype.toString = function() {
  return this.join();
}
